import AcmePlatform
import Foundation

extension Imaging {
    /// Moves care protocol batches through their life cycle and keeps a journal of what it did.
    final class CareProtocolBatchCoordinator {
        var store: any CareProtocolBatchStore
        var validator: CareProtocolBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareProtocolBatchStore, validator: CareProtocolBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolBatchStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolBatchStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newCareProtocolBatchCoordinator(_ store: any CareProtocolBatchStore, clock: any Kit.Clocks.Clock) -> CareProtocolBatchCoordinator {
        return CareProtocolBatchCoordinator(
            store: store,
            validator: defaultCareProtocolBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
