import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance schedules through their life cycle and keeps a journal of what it did.
    final class RemittanceScheduleCoordinator {
        var store: any RemittanceScheduleStore
        var validator: RemittanceScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceScheduleEngine

        init(store: any RemittanceScheduleStore, validator: RemittanceScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceScheduleEngine) {
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
                throw Kit.Failure("remittance schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceScheduleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceScheduleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance schedule \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newRemittanceScheduleCoordinator(_ store: any RemittanceScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RemittanceScheduleCoordinator {
        return RemittanceScheduleCoordinator(
            store: store,
            validator: defaultRemittanceScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceScheduleEngine(flags)
        )
    }
}
