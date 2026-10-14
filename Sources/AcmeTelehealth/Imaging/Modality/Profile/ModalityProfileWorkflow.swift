import AcmePlatform
import Foundation

extension Imaging {
    /// Moves modality profiles through their life cycle and keeps a journal of what it did.
    final class ModalityProfileManager {
        var store: any ModalityProfileStore
        var validator: ModalityProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ModalityProfileStore, validator: ModalityProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("modality profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ModalityProfileStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ModalityProfileStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newModalityProfileManager(_ store: any ModalityProfileStore, clock: any Kit.Clocks.Clock) -> ModalityProfileManager {
        return ModalityProfileManager(
            store: store,
            validator: defaultModalityProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
