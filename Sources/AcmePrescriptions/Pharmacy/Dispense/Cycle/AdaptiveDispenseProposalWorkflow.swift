import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves adaptive dispense proposals through their life cycle and keeps a journal of what it did.
    final class AdaptiveDispenseProposalDesk {
        var store: any AdaptiveDispenseProposalStore
        var validator: AdaptiveDispenseProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveDispenseProposalStore, validator: AdaptiveDispenseProposalValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("adaptive dispense proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveDispenseProposalStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive dispense proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveDispenseProposalStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newAdaptiveDispenseProposalDesk(_ store: any AdaptiveDispenseProposalStore, clock: any Kit.Clocks.Clock) -> AdaptiveDispenseProposalDesk {
        return AdaptiveDispenseProposalDesk(
            store: store,
            validator: defaultAdaptiveDispenseProposalValidator(),
            clock: clock,
            journal: []
        )
    }
}
