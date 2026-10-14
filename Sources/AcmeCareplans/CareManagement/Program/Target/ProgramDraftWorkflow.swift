import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves program drafts through their life cycle and keeps a journal of what it did.
    final class ProgramDraftManager {
        var store: any ProgramDraftStore
        var validator: ProgramDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProgramDraftEngine

        init(store: any ProgramDraftStore, validator: ProgramDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProgramDraftEngine) {
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
                throw Kit.Failure("program draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProgramDraftStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProgramDraftStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("program draft \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newProgramDraftManager(_ store: any ProgramDraftStore, clock: any Kit.Clocks.Clock) -> ProgramDraftManager {
        return ProgramDraftManager(
            store: store,
            validator: defaultProgramDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultProgramDraftEngine()
        )
    }
}
