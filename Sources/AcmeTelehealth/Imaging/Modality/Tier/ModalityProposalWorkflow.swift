import AcmePlatform
import Foundation

extension Imaging {
    /// Moves modality proposals through their life cycle and keeps a journal of what it did.
    final class ModalityProposalCoordinator {
        var store: any ModalityProposalStore
        var validator: ModalityProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ModalityProposalStore, validator: ModalityProposalValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("modality proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ModalityProposalStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ModalityProposalStatus.withdrawn)
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

    static func newModalityProposalCoordinator(_ store: any ModalityProposalStore, clock: any Kit.Clocks.Clock) -> ModalityProposalCoordinator {
        return ModalityProposalCoordinator(
            store: store,
            validator: defaultModalityProposalValidator(),
            clock: clock,
            journal: []
        )
    }
}
