import AcmePlatform
import Foundation

extension Referrals {
    /// Moves fallback network schedules through their life cycle and keeps a journal of what it did.
    final class FallbackNetworkScheduleWorkflow {
        var store: any FallbackNetworkScheduleStore
        var validator: FallbackNetworkScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackNetworkScheduleEngine

        init(store: any FallbackNetworkScheduleStore, validator: FallbackNetworkScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackNetworkScheduleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback network schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackNetworkScheduleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback network schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackNetworkScheduleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback network schedule \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newFallbackNetworkScheduleWorkflow(_ store: any FallbackNetworkScheduleStore, clock: any Kit.Clocks.Clock) -> FallbackNetworkScheduleWorkflow {
        return FallbackNetworkScheduleWorkflow(
            store: store,
            validator: defaultFallbackNetworkScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackNetworkScheduleEngine()
        )
    }
}
