import AcmePlatform
import Foundation

extension Labs {
    /// Moves primary panel schedules through their life cycle and keeps a journal of what it did.
    final class PrimaryPanelScheduleService {
        var store: any PrimaryPanelScheduleStore
        var validator: PrimaryPanelScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryPanelScheduleEngine

        init(store: any PrimaryPanelScheduleStore, validator: PrimaryPanelScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryPanelScheduleEngine) {
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
                throw Kit.Failure("primary panel schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryPanelScheduleStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary panel schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryPanelScheduleStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary panel schedule \(code) not found")
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

    static func newPrimaryPanelScheduleService(_ store: any PrimaryPanelScheduleStore, clock: any Kit.Clocks.Clock) -> PrimaryPanelScheduleService {
        return PrimaryPanelScheduleService(
            store: store,
            validator: defaultPrimaryPanelScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryPanelScheduleEngine()
        )
    }
}
