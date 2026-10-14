import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves rolling program drafts through their life cycle and keeps a journal of what it did.
    final class RollingProgramDraftDesk {
        var store: any RollingProgramDraftStore
        var validator: RollingProgramDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingProgramDraftEngine

        init(store: any RollingProgramDraftStore, validator: RollingProgramDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingProgramDraftEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling program draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingProgramDraftStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling program draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingProgramDraftStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling program draft \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newRollingProgramDraftDesk(_ store: any RollingProgramDraftStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingProgramDraftDesk {
        return RollingProgramDraftDesk(
            store: store,
            validator: defaultRollingProgramDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingProgramDraftEngine(flags)
        )
    }
}
