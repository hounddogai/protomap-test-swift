import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves program snapshots through their life cycle and keeps a journal of what it did.
    final class ProgramSnapshotWorkflow {
        var store: any ProgramSnapshotStore
        var validator: ProgramSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProgramSnapshotEngine

        init(store: any ProgramSnapshotStore, validator: ProgramSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProgramSnapshotEngine) {
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
                throw Kit.Failure("program snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProgramSnapshotStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProgramSnapshotStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("program snapshot \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newProgramSnapshotWorkflow(_ store: any ProgramSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ProgramSnapshotWorkflow {
        return ProgramSnapshotWorkflow(
            store: store,
            validator: defaultProgramSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultProgramSnapshotEngine(flags)
        )
    }
}
