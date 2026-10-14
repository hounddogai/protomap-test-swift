import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves scheduled charge digests through their life cycle and keeps a journal of what it did.
    final class ScheduledChargeDigestManager {
        var store: any ScheduledChargeDigestStore
        var validator: ScheduledChargeDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledChargeDigestEngine

        init(store: any ScheduledChargeDigestStore, validator: ScheduledChargeDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledChargeDigestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled charge digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledChargeDigestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled charge digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledChargeDigestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled charge digest \(code) not found")
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

    static func newScheduledChargeDigestManager(_ store: any ScheduledChargeDigestStore, clock: any Kit.Clocks.Clock) -> ScheduledChargeDigestManager {
        return ScheduledChargeDigestManager(
            store: store,
            validator: defaultScheduledChargeDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledChargeDigestEngine()
        )
    }
}
