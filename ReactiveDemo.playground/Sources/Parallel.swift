import Foundation

public struct Parallel<A> {
    public let run: (@escaping (A) -> Void) -> Void
}

extension Parallel {
    public init(_ run: @escaping (@escaping (A) -> Void) -> Void) {
        self.run = run
    }
    
    public func map<B>(_ f: @escaping (A) -> B) -> Parallel<B> {
        return Parallel<B> { callback in
            self.run { a in
                callback(f(a))
            }
        }
    }
}

public func zip2<A, B>(_ fa: Parallel<A>, _ fb: Parallel<B>) -> Parallel<(A, B)> {
    return Parallel { callback in
        fa.run { a in
            fb.run { b in
                callback((a, b))
            }
        }
    }
}

public func zip3<A, B, C>(_ fa: Parallel<A>, _ fb: Parallel<B>, _ fc: Parallel<C>) -> Parallel<(A, B, C)> {
    return zip2(fa, zip2(fb, fc)).map { ($0, $1.0, $1.1) }
}

public func zip3<A, B, C, D>(
    with f: @escaping (A, B, C) -> D
    ) -> (Parallel<A>, Parallel<B>, Parallel<C>) -> Parallel<D> {
    
    return { zip3($0, $1, $2).map(f) }
}

public func zip<A, B, C>(with f: @escaping (A, B) -> C) -> (Parallel<A>, Parallel<B>) -> Parallel<C> {
    return { zip2($0, $1).map(f) }
}
