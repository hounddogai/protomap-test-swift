import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves adaptive transfer entries through their life cycle and keeps a journal of what it did.
    final class AdaptiveTransferEntryCoordinator {
        var store: any AdaptiveTransferEntryStore
        var validator: AdaptiveTransferEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveTransferEntryStore, validator: AdaptiveTransferEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("adaptive transfer entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveTransferEntryStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive transfer entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveTransferEntryStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newAdaptiveTransferEntryCoordinator(_ store: any AdaptiveTransferEntryStore, clock: any Kit.Clocks.Clock) -> AdaptiveTransferEntryCoordinator {
        return AdaptiveTransferEntryCoordinator(
            store: store,
            validator: defaultAdaptiveTransferEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
