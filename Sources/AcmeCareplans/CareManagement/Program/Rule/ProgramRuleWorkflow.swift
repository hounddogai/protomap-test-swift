import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves program rules through their life cycle and keeps a journal of what it did.
    final class ProgramRuleService {
        var store: any ProgramRuleStore
        var validator: ProgramRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ProgramRuleStore, validator: ProgramRuleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProgramRuleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProgramRuleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newProgramRuleService(_ store: any ProgramRuleStore, clock: any Kit.Clocks.Clock) -> ProgramRuleService {
        return ProgramRuleService(store: store, validator: defaultProgramRuleValidator(), clock: clock, journal: [])
    }
}
