import Foundation

/// The toolkit every area of the code base shares, by topic: `Kit.Text`, `Kit.Caching`, and the rest.
public enum Kit {
    /// Small string helpers shared by every area.
    public enum Text {}

    /// Generic helpers over arrays and dictionaries.
    public enum Collections {}

    /// Arithmetic helpers: clamping, rounding, and simple statistics.
    public enum Numbers {}

    /// Amounts of money in minor units, with their currency.
    public enum Money {}

    /// Clocks, so code that reads the time can be tested.
    public enum Clocks {}

    /// An in-memory cache with a time to live and a capacity.
    public enum Caching {}

    /// Retry policies with pluggable backoff.
    public enum Retry {}

    /// Feature flags with rollout strategies.
    public enum Flags {}

    /// Plain-text and CSV tables for reports.
    public enum Tables {}

    /// Identifiers and references.
    public enum IDs {}

    /// Why a kit or domain operation refused to go on.
    public struct Failure: Error, CustomStringConvertible, Sendable {
        public let message: String

        public init(_ message: String) {
            self.message = message
        }

        public var description: String { message }
    }

    /// A hash of the text that is the same in every process, unlike `hashValue`, for rollouts and sharding.
    public static func stableHash(_ text: String) -> Int {
        var hash: UInt32 = 2_166_136_261
        for byte in text.utf8 {
            hash = (hash ^ UInt32(byte)) &* 16_777_619
        }
        return Int(hash)
    }
}
