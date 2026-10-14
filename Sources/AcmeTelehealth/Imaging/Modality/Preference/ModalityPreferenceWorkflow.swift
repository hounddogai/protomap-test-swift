import AcmePlatform
import Foundation

extension Imaging {
    /// Moves modality preferences through their life cycle and keeps a journal of what it did.
    final class ModalityPreferenceWorkflow {
        var store: any ModalityPreferenceStore
        var validator: ModalityPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ModalityPreferenceStore, validator: ModalityPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("modality preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ModalityPreferenceStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ModalityPreferenceStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newModalityPreferenceWorkflow(_ store: any ModalityPreferenceStore, clock: any Kit.Clocks.Clock) -> ModalityPreferenceWorkflow {
        return ModalityPreferenceWorkflow(
            store: store,
            validator: defaultModalityPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
