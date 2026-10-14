import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves lenient authorization digests through their life cycle and keeps a journal of what it did.
    final class LenientAuthorizationDigestDesk {
        var store: any LenientAuthorizationDigestStore
        var validator: LenientAuthorizationDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientAuthorizationDigestEngine

        init(store: any LenientAuthorizationDigestStore, validator: LenientAuthorizationDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientAuthorizationDigestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient authorization digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientAuthorizationDigestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient authorization digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientAuthorizationDigestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient authorization digest \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newLenientAuthorizationDigestDesk(_ store: any LenientAuthorizationDigestStore, clock: any Kit.Clocks.Clock) -> LenientAuthorizationDigestDesk {
        return LenientAuthorizationDigestDesk(
            store: store,
            validator: defaultLenientAuthorizationDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientAuthorizationDigestEngine()
        )
    }
}
