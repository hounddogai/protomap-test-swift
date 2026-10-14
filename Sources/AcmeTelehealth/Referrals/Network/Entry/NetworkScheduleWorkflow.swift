import AcmePlatform
import Foundation

extension Referrals {
    /// Moves network schedules through their life cycle and keeps a journal of what it did.
    final class NetworkScheduleWorkflow {
        var store: any NetworkScheduleStore
        var validator: NetworkScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: NetworkScheduleEngine

        init(store: any NetworkScheduleStore, validator: NetworkScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: NetworkScheduleEngine) {
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
                throw Kit.Failure("network schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(NetworkScheduleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(NetworkScheduleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("network schedule \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newNetworkScheduleWorkflow(_ store: any NetworkScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> NetworkScheduleWorkflow {
        return NetworkScheduleWorkflow(
            store: store,
            validator: defaultNetworkScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultNetworkScheduleEngine(flags)
        )
    }
}
