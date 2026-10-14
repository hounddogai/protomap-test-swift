import AcmePlatform
import Foundation

extension Staffing {
    /// Moves overtime audits through their life cycle and keeps a journal of what it did.
    final class OvertimeAuditCoordinator {
        var store: any OvertimeAuditStore
        var validator: OvertimeAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OvertimeAuditEngine

        init(store: any OvertimeAuditStore, validator: OvertimeAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OvertimeAuditEngine) {
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
                throw Kit.Failure("overtime audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OvertimeAuditStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OvertimeAuditStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime audit \(code) not found")
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

    static func newOvertimeAuditCoordinator(_ store: any OvertimeAuditStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> OvertimeAuditCoordinator {
        return OvertimeAuditCoordinator(
            store: store,
            validator: defaultOvertimeAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultOvertimeAuditEngine(flags)
        )
    }
}
