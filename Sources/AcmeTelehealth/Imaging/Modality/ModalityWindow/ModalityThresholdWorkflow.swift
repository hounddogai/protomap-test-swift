import AcmePlatform
import Foundation

extension Imaging {
    /// Moves modality thresholds through their life cycle and keeps a journal of what it did.
    final class ModalityThresholdCoordinator {
        var store: any ModalityThresholdStore
        var validator: ModalityThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ModalityThresholdStore, validator: ModalityThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("modality threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ModalityThresholdStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ModalityThresholdStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newModalityThresholdCoordinator(_ store: any ModalityThresholdStore, clock: any Kit.Clocks.Clock) -> ModalityThresholdCoordinator {
        return ModalityThresholdCoordinator(
            store: store,
            validator: defaultModalityThresholdValidator(),
            clock: clock,
            journal: []
        )
    }
}
