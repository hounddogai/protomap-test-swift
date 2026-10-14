import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves care protocol batches through their life cycle and keeps a journal of what it did.
    final class CareProtocolBatchManager {
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

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolBatchStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolBatchStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newCareProtocolBatchManager(_ store: any CareProtocolBatchStore, clock: any Kit.Clocks.Clock) -> CareProtocolBatchManager {
        return CareProtocolBatchManager(
            store: store,
            validator: defaultCareProtocolBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
