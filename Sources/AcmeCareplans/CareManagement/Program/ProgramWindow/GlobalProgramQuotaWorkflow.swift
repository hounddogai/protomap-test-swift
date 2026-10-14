import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves global program quotas through their life cycle and keeps a journal of what it did.
    final class GlobalProgramQuotaWorkflow {
        var store: any GlobalProgramQuotaStore
        var validator: GlobalProgramQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalProgramQuotaStore, validator: GlobalProgramQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global program quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalProgramQuotaStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global program quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalProgramQuotaStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newGlobalProgramQuotaWorkflow(_ store: any GlobalProgramQuotaStore, clock: any Kit.Clocks.Clock) -> GlobalProgramQuotaWorkflow {
        return GlobalProgramQuotaWorkflow(
            store: store,
            validator: defaultGlobalProgramQuotaValidator(),
            clock: clock,
            journal: []
        )
    }
}
