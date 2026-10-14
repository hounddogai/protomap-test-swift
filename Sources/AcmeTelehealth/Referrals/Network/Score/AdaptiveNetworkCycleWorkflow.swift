import AcmePlatform
import Foundation

extension Referrals {
    /// Moves adaptive network cycles through their life cycle and keeps a journal of what it did.
    final class AdaptiveNetworkCycleManager {
        var store: any AdaptiveNetworkCycleStore
        var validator: AdaptiveNetworkCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveNetworkCycleStore, validator: AdaptiveNetworkCycleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("adaptive network cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveNetworkCycleStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive network cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveNetworkCycleStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newAdaptiveNetworkCycleManager(_ store: any AdaptiveNetworkCycleStore, clock: any Kit.Clocks.Clock) -> AdaptiveNetworkCycleManager {
        return AdaptiveNetworkCycleManager(
            store: store,
            validator: defaultAdaptiveNetworkCycleValidator(),
            clock: clock,
            journal: []
        )
    }
}
