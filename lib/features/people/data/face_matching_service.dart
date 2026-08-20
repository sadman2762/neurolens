import 'dart:math' as math;

import 'package:flutter/foundation.dart';

class FaceMatchingService {
  const FaceMatchingService({
    this.matchThreshold = 0.72,
    this.strongMatchThreshold = 0.82,
  });

  /// Minimum cosine similarity required to consider two
  /// face embeddings the same person.
  ///
  /// Keep this conservative until we collect real scores
  /// from NeuroLens photos.
  final double matchThreshold;

  /// Similarity at which we consider the match high confidence.
  final double strongMatchThreshold;

  // ===========================================================================
  // Compare two embeddings
  // ===========================================================================

  FaceMatchResult compare({
    required List<double> first,
    required List<double> second,
  }) {
    _validateEmbeddings(
      first,
      second,
    );

    final similarity = cosineSimilarity(
      first,
      second,
    );

    final result = FaceMatchResult(
      similarity: similarity,
      isMatch: similarity >= matchThreshold,
      isStrongMatch:
          similarity >= strongMatchThreshold,
    );

    if (kDebugMode) {
      debugPrint(
        '===== Face comparison =====',
      );
      debugPrint(
        'Similarity: ${similarity.toStringAsFixed(4)}',
      );
      debugPrint(
        'Match threshold: '
        '${matchThreshold.toStringAsFixed(4)}',
      );
      debugPrint(
        'Strong threshold: '
        '${strongMatchThreshold.toStringAsFixed(4)}',
      );
      debugPrint(
        'Decision: '
        '${result.isMatch ? 'MATCH' : 'NO MATCH'}',
      );
      debugPrint(
        '===========================',
      );
    }

    return result;
  }

  // ===========================================================================
  // Cosine similarity
  // ===========================================================================

  double cosineSimilarity(
    List<double> first,
    List<double> second,
  ) {
    _validateEmbeddings(
      first,
      second,
    );

    var dotProduct = 0.0;
    var firstMagnitude = 0.0;
    var secondMagnitude = 0.0;

    for (
      var index = 0;
      index < first.length;
      index++
    ) {
      final firstValue = first[index];
      final secondValue = second[index];

      if (!firstValue.isFinite ||
          !secondValue.isFinite) {
        throw const FaceMatchingException(
          'Face embedding contains a '
          'non-finite value.',
        );
      }

      dotProduct +=
          firstValue * secondValue;

      firstMagnitude +=
          firstValue * firstValue;

      secondMagnitude +=
          secondValue * secondValue;
    }

    if (firstMagnitude <= 0 ||
        secondMagnitude <= 0) {
      throw const FaceMatchingException(
        'Cannot compare zero-length embeddings.',
      );
    }

    final denominator =
        math.sqrt(firstMagnitude) *
        math.sqrt(secondMagnitude);

    if (!denominator.isFinite ||
        denominator <= 0) {
      throw const FaceMatchingException(
        'Invalid embedding magnitude.',
      );
    }

    final similarity =
        dotProduct / denominator;

    if (!similarity.isFinite) {
      throw const FaceMatchingException(
        'Face similarity calculation '
        'returned an invalid value.',
      );
    }

    return similarity.clamp(
      -1.0,
      1.0,
    );
  }

  // ===========================================================================
  // Find best match
  // ===========================================================================

  FaceCandidateMatch? findBestMatch({
    required List<double> queryEmbedding,
    required Iterable<FaceMatchCandidate>
        candidates,
  }) {
    if (queryEmbedding.isEmpty) {
      throw const FaceMatchingException(
        'Query face embedding cannot be empty.',
      );
    }

    FaceCandidateMatch? bestMatch;

    var totalCandidates = 0;
    var compatibleCandidates = 0;

    if (kDebugMode) {
      debugPrint(
        '===== Face matching =====',
      );
      debugPrint(
        'Query dimension: ${queryEmbedding.length}',
      );
      debugPrint(
        'Match threshold: '
        '${matchThreshold.toStringAsFixed(4)}',
      );
      debugPrint(
        'Strong threshold: '
        '${strongMatchThreshold.toStringAsFixed(4)}',
      );
    }

    for (final candidate in candidates) {
      totalCandidates++;

      if (candidate.embedding.length !=
          queryEmbedding.length) {
        if (kDebugMode) {
          debugPrint(
            'Candidate ${candidate.id}: '
            'SKIPPED '
            '(dimension '
            '${candidate.embedding.length})',
          );
        }

        continue;
      }

      compatibleCandidates++;

      final similarity = cosineSimilarity(
        queryEmbedding,
        candidate.embedding,
      );

      final isMatch =
          similarity >= matchThreshold;

      final isStrongMatch =
          similarity >= strongMatchThreshold;

      if (kDebugMode) {
        debugPrint(
          'Candidate ${candidate.id}',
        );
        debugPrint(
          '  Person: '
          '${candidate.personId ?? 'unassigned'}',
        );
        debugPrint(
          '  Similarity: '
          '${similarity.toStringAsFixed(4)}',
        );
        debugPrint(
          '  Decision: '
          '${isMatch ? 'MATCH' : 'NO MATCH'}',
        );
      }

      if (bestMatch == null ||
          similarity > bestMatch.similarity) {
        bestMatch = FaceCandidateMatch(
          candidateId: candidate.id,
          personId: candidate.personId,
          similarity: similarity,
          isMatch: isMatch,
          isStrongMatch: isStrongMatch,
        );
      }
    }

    if (kDebugMode) {
      debugPrint(
        'Total candidates: $totalCandidates',
      );

      debugPrint(
        'Compatible candidates: '
        '$compatibleCandidates',
      );

      if (bestMatch == null) {
        debugPrint(
          'Best similarity: none',
        );

        debugPrint(
          'Decision: NEW PERSON',
        );
      } else {
        debugPrint(
          'Best candidate: '
          '${bestMatch.candidateId}',
        );

        debugPrint(
          'Best person: '
          '${bestMatch.personId ?? 'unassigned'}',
        );

        debugPrint(
          'Best similarity: '
          '${bestMatch.similarity.toStringAsFixed(4)}',
        );

        debugPrint(
          'Decision: '
          '${bestMatch.isMatch ? 'MATCH' : 'NEW PERSON'}',
        );
      }

      debugPrint(
        '=========================',
      );
    }

    return bestMatch;
  }

  // ===========================================================================
  // Rank matches
  // ===========================================================================

  List<FaceCandidateMatch> rankMatches({
    required List<double> queryEmbedding,
    required Iterable<FaceMatchCandidate>
        candidates,
    int? limit,
  }) {
    if (queryEmbedding.isEmpty) {
      throw const FaceMatchingException(
        'Query face embedding cannot be empty.',
      );
    }

    final matches =
        <FaceCandidateMatch>[];

    for (final candidate in candidates) {
      if (candidate.embedding.length !=
          queryEmbedding.length) {
        continue;
      }

      final similarity = cosineSimilarity(
        queryEmbedding,
        candidate.embedding,
      );

      matches.add(
        FaceCandidateMatch(
          candidateId: candidate.id,
          personId: candidate.personId,
          similarity: similarity,
          isMatch:
              similarity >= matchThreshold,
          isStrongMatch:
              similarity >=
                  strongMatchThreshold,
        ),
      );
    }

    matches.sort(
      (first, second) =>
          second.similarity.compareTo(
        first.similarity,
      ),
    );

    if (limit != null) {
      if (limit < 0) {
        throw const FaceMatchingException(
          'Match ranking limit cannot be negative.',
        );
      }

      if (matches.length > limit) {
        return List.unmodifiable(
          matches.take(limit),
        );
      }
    }

    return List.unmodifiable(
      matches,
    );
  }

  // ===========================================================================
  // Average embeddings
  // ===========================================================================

  List<double> averageEmbeddings(
    Iterable<List<double>> embeddings,
  ) {
    final list = embeddings.toList(
      growable: false,
    );

    if (list.isEmpty) {
      throw const FaceMatchingException(
        'At least one embedding is required.',
      );
    }

    final dimension =
        list.first.length;

    if (dimension == 0) {
      throw const FaceMatchingException(
        'Embedding dimension cannot be zero.',
      );
    }

    for (final embedding in list) {
      if (embedding.length != dimension) {
        throw const FaceMatchingException(
          'Cannot average embeddings with '
          'different dimensions.',
        );
      }

      for (final value in embedding) {
        if (!value.isFinite) {
          throw const FaceMatchingException(
            'Cannot average embeddings '
            'containing non-finite values.',
          );
        }
      }
    }

    final average =
        List<double>.filled(
      dimension,
      0.0,
      growable: false,
    );

    for (final embedding in list) {
      for (
        var index = 0;
        index < dimension;
        index++
      ) {
        average[index] +=
            embedding[index];
      }
    }

    for (
      var index = 0;
      index < dimension;
      index++
    ) {
      average[index] /=
          list.length;
    }

    return _l2Normalize(
      average,
    );
  }

  // ===========================================================================
  // Normalize embedding
  // ===========================================================================

  List<double> _l2Normalize(
    List<double> embedding,
  ) {
    if (embedding.isEmpty) {
      throw const FaceMatchingException(
        'Cannot normalize an empty embedding.',
      );
    }

    var sumSquares = 0.0;

    for (final value in embedding) {
      if (!value.isFinite) {
        throw const FaceMatchingException(
          'Cannot normalize an embedding '
          'containing non-finite values.',
        );
      }

      sumSquares +=
          value * value;
    }

    final magnitude =
        math.sqrt(sumSquares);

    if (!magnitude.isFinite ||
        magnitude <= 0) {
      throw const FaceMatchingException(
        'Cannot normalize a zero-length '
        'embedding.',
      );
    }

    return embedding
        .map(
          (value) =>
              value / magnitude,
        )
        .toList(
          growable: false,
        );
  }

  // ===========================================================================
  // Validation
  // ===========================================================================

  void _validateEmbeddings(
    List<double> first,
    List<double> second,
  ) {
    if (first.isEmpty ||
        second.isEmpty) {
      throw const FaceMatchingException(
        'Face embeddings cannot be empty.',
      );
    }

    if (first.length != second.length) {
      throw FaceMatchingException(
        'Embedding dimensions do not match. '
        'First: ${first.length}, '
        'second: ${second.length}.',
      );
    }
  }
}

// =============================================================================
// Candidate
// =============================================================================

class FaceMatchCandidate {
  const FaceMatchCandidate({
    required this.id,
    required this.embedding,
    this.personId,
  });

  final String id;
  final String? personId;
  final List<double> embedding;
}

// =============================================================================
// Direct comparison result
// =============================================================================

class FaceMatchResult {
  const FaceMatchResult({
    required this.similarity,
    required this.isMatch,
    required this.isStrongMatch,
  });

  final double similarity;
  final bool isMatch;
  final bool isStrongMatch;
}

// =============================================================================
// Candidate comparison result
// =============================================================================

class FaceCandidateMatch {
  const FaceCandidateMatch({
    required this.candidateId,
    required this.personId,
    required this.similarity,
    required this.isMatch,
    required this.isStrongMatch,
  });

  final String candidateId;
  final String? personId;
  final double similarity;
  final bool isMatch;
  final bool isStrongMatch;
}

// =============================================================================
// Exception
// =============================================================================

class FaceMatchingException
    implements Exception {
  const FaceMatchingException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}