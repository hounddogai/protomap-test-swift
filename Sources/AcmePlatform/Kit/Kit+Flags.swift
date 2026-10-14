import Foundation

extension Kit.Flags {
    /// Strategy decides whether a flag is on for a subject.
    public protocol Strategy {
        func allows(_ subject: String) -> Bool
    }

    public final class PercentStrategy: Strategy {
        public var rollout: Int
        public var salt: String

        public init(rollout: Int, salt: String) {
            self.rollout = rollout
            self.salt = salt
        }

        public func allows(_ subject: String) -> Bool {
            let bucket = Kit.stableHash(salt + subject) % 100
            return bucket < rollout
        }
    }

    public final class AllowListStrategy: Strategy {
        public var subjects: [String]

        public init(subjects: [String]) {
            self.subjects = subjects
        }

        public func allows(_ subject: String) -> Bool {
            return subjects.contains(subject)
        }
    }

    public final class PrefixStrategy: Strategy {
        public var prefix: String

        public init(prefix: String) {
            self.prefix = prefix
        }

        public func allows(_ subject: String) -> Bool {
            return subject.hasPrefix(prefix)
        }
    }

    public final class AllOf: Strategy {
        public var parts: [any Strategy]

        public init(parts: [any Strategy]) {
            self.parts = parts
        }

        public func allows(_ subject: String) -> Bool {
            for part in parts {
                if !part.allows(subject) {
                    return false
                }
            }
            return true
        }
    }

    public final class AnyOf: Strategy {
        public var parts: [any Strategy]

        public init(parts: [any Strategy]) {
            self.parts = parts
        }

        public func allows(_ subject: String) -> Bool {
            for part in parts {
                if part.allows(subject) {
                    return true
                }
            }
            return false
        }
    }

    public final class Flag {
        public var name: String
        public var enabled: Bool
        public var strategy: any Strategy

        public init(name: String, enabled: Bool, strategy: any Strategy) {
            self.name = name
            self.enabled = enabled
            self.strategy = strategy
        }
    }

    /// Registry holds the flags of a process by name.
    public final class Registry {
        public var flags: [String: Flag]

        public init(flags: [String: Flag]) {
            self.flags = flags
        }

        public func register(_ flag: Flag) {
            flags[flag.name] = flag
        }

        public func enabled(_ name: String, subject: String) -> Bool {
            guard let found = flags[name] else {
                return false
            }
            if !found.enabled {
                return false
            }
            return found.strategy.allows(subject)
        }

        public func names() -> [String] {
            return flags.keys.sorted()
        }
    }

    public static func newRegistry() -> Registry {
        return Registry(flags: [:])
    }
}
