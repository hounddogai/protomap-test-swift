import AcmePlatform
import Foundation

extension Imaging {
    /// Moves modality entries through their life cycle and keeps a journal of what it did.
    final class ModalityEntryService {
        var store: any ModalityEntryStore
        var validator: ModalityEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ModalityEntryStore, validator: ModalityEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("modality entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ModalityEntryStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ModalityEntryStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newModalityEntryService(_ store: any ModalityEntryStore, clock: any Kit.Clocks.Clock) -> ModalityEntryService {
        return ModalityEntryService(
            store: store,
            validator: defaultModalityEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
