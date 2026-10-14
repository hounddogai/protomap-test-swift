import AcmePlatform
import Foundation

extension Labs {
    /// Moves specimen batches through their life cycle and keeps a journal of what it did.
    final class SpecimenBatchWorkflow {
        var store: any SpecimenBatchStore
        var validator: SpecimenBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SpecimenBatchStore, validator: SpecimenBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("specimen batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SpecimenBatchStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SpecimenBatchStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newSpecimenBatchWorkflow(_ store: any SpecimenBatchStore, clock: any Kit.Clocks.Clock) -> SpecimenBatchWorkflow {
        return SpecimenBatchWorkflow(
            store: store,
            validator: defaultSpecimenBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
