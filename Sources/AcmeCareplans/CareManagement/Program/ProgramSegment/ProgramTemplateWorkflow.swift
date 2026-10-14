import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves program templates through their life cycle and keeps a journal of what it did.
    final class ProgramTemplateService {
        var store: any ProgramTemplateStore
        var validator: ProgramTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ProgramTemplateStore, validator: ProgramTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("program template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProgramTemplateStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProgramTemplateStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newProgramTemplateService(_ store: any ProgramTemplateStore, clock: any Kit.Clocks.Clock) -> ProgramTemplateService {
        return ProgramTemplateService(
            store: store,
            validator: defaultProgramTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
