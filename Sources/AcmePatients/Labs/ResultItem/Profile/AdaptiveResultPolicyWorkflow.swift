import AcmePlatform
import Foundation

extension Labs {
    /// Moves adaptive result policies through their life cycle and keeps a journal of what it did.
    final class AdaptiveResultPolicyDesk {
        var store: any AdaptiveResultPolicyStore
        var validator: AdaptiveResultPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveResultPolicyStore, validator: AdaptiveResultPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("adaptive result policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveResultPolicyStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive result policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveResultPolicyStatus.withdrawn)
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

    static func newAdaptiveResultPolicyDesk(_ store: any AdaptiveResultPolicyStore, clock: any Kit.Clocks.Clock) -> AdaptiveResultPolicyDesk {
        return AdaptiveResultPolicyDesk(
            store: store,
            validator: defaultAdaptiveResultPolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
