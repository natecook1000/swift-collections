//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

public enum Either_<Left, Right> {
  case left(Left)
  case right(Right)
}
extension Either_: Error where Left: Error, Right: Error {}
extension Either_: Sendable where Left: Sendable, Right: Sendable {}

extension Either_ {
  @inlinable
  static func doLeft<T: ~Copyable & ~Escapable>(_ body: () throws(Left) -> T) throws(Either_) -> T {
    do {
      return try body()
    } catch {
      throw Either_.left(error)
    }
  }
  
  @inlinable
  static func doRight<T: ~Copyable & ~Escapable>(_ body: () throws(Right) -> T) throws(Either_) -> T {
    do {
      return try body()
    } catch {
      throw Either_.right(error)
    }
  }
}

//func catchEither<T: ~Copyable, L: Error, R: Error>(_ body: () throws(L) -> T, _unusedError: R.Type = R.self) throws(Either_<L, R>) -> T {
//  do {
//    return try body()
//  } catch {
//    throw Either_.left(error)
//  }
//}
//func catchEither<T: ~Copyable, L: Error, R: Error>(_ body: () throws(R) -> T, _unusedError: L.Type = L.self) throws(Either_<L, R>) -> T {
//  do {
//    return try body()
//  } catch {
//    throw Either_.right(error)
//  }
//}

@available(SwiftStdlib 5.0, *)
extension BorrowingIteratorProtocol_
where
  Self: ~Copyable & ~Escapable,
  Element_: ~Copyable
{
  @inlinable
  public consuming func reduce<Result: ~Copyable, E: Error>(
    _ initialResult: consuming Result,
    _ nextPartialResult: (consuming Result, borrowing Element_) throws(E) -> Result
  ) throws(Either_<Error_, E>) -> Result {
    var result = initialResult
    while true {
      let span = try Either_<Error_, E>.doLeft { try self.nextSpan_() }
      guard !span.isEmpty else { break }
      var i = 0
      while i < span.count {
        result = try Either_<Error_, E>.doRight { try nextPartialResult(result, span[unchecked: i]) }
        i &+= 1
      }
    }
    return result
  }

  @inlinable
  public consuming func reduce<Result: ~Copyable, E: Error>(
    into initialResult: consuming Result,
    _ updateAccumulatingResult: (inout Result, borrowing Element_) throws(E) -> Void
  ) throws(Either_<Error_, E>) -> Result {
    var result = initialResult
    while true {
      let span = try Either_<Error_, E>.doLeft { try self.nextSpan_() }
      guard !span.isEmpty else { break }
      var i = 0
      while i < span.count {
        try Either_<Error_, E>.doRight { try updateAccumulatingResult(&result, span[unchecked: i]) }
        i &+= 1
      }
    }
    return result
  }
}

#endif
