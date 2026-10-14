import AcmePlatform
import Foundation

extension Labs {
    /// Moves panel batches through their life cycle and keeps a journal of what it did.
    final class PanelBatchCoordinator {
        var store: any PanelBatchStore
        var validator: PanelBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PanelBatchStore, validator: PanelBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PanelBatchStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PanelBatchStatus.withdrawn)
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

    static func newPanelBatchCoordinator(_ store: any PanelBatchStore, clock: any Kit.Clocks.Clock) -> PanelBatchCoordinator {
        return PanelBatchCoordinator(
            store: store,
            validator: defaultPanelBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
