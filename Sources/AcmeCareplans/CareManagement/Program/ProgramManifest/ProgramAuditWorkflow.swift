import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves program audits through their life cycle and keeps a journal of what it did.
    final class ProgramAuditDesk {
        var store: any ProgramAuditStore
        var validator: ProgramAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProgramAuditEngine

        init(store: any ProgramAuditStore, validator: ProgramAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProgramAuditEngine) {
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
                throw Kit.Failure("program audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProgramAuditStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProgramAuditStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("program audit \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newProgramAuditDesk(_ store: any ProgramAuditStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ProgramAuditDesk {
        return ProgramAuditDesk(
            store: store,
            validator: defaultProgramAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultProgramAuditEngine(flags)
        )
    }
}
