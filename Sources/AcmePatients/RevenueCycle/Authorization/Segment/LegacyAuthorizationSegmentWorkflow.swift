import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves legacy authorization segments through their life cycle and keeps a journal of what it did.
    final class LegacyAuthorizationSegmentCoordinator {
        var store: any LegacyAuthorizationSegmentStore
        var validator: LegacyAuthorizationSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyAuthorizationSegmentEngine

        init(store: any LegacyAuthorizationSegmentStore, validator: LegacyAuthorizationSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyAuthorizationSegmentEngine) {
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
                throw Kit.Failure("legacy authorization segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyAuthorizationSegmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy authorization segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyAuthorizationSegmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy authorization segment \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newLegacyAuthorizationSegmentCoordinator(_ store: any LegacyAuthorizationSegmentStore, clock: any Kit.Clocks.Clock) -> LegacyAuthorizationSegmentCoordinator {
        return LegacyAuthorizationSegmentCoordinator(
            store: store,
            validator: defaultLegacyAuthorizationSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyAuthorizationSegmentEngine()
        )
    }
}
