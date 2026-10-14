import AcmePlatform
import Foundation

extension Labs {
    /// Moves capped panel audits through their life cycle and keeps a journal of what it did.
    final class CappedPanelAuditManager {
        var store: any CappedPanelAuditStore
        var validator: CappedPanelAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedPanelAuditStore, validator: CappedPanelAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped panel audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedPanelAuditStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped panel audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedPanelAuditStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newCappedPanelAuditManager(_ store: any CappedPanelAuditStore, clock: any Kit.Clocks.Clock) -> CappedPanelAuditManager {
        return CappedPanelAuditManager(
            store: store,
            validator: defaultCappedPanelAuditValidator(),
            clock: clock,
            journal: []
        )
    }
}
