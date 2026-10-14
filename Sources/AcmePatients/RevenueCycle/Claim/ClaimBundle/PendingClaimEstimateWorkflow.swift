import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves pending claim estimates through their life cycle and keeps a journal of what it did.
    final class PendingClaimEstimateCoordinator {
        var store: any PendingClaimEstimateStore
        var validator: PendingClaimEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingClaimEstimateStore, validator: PendingClaimEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending claim estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingClaimEstimateStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending claim estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingClaimEstimateStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newPendingClaimEstimateCoordinator(_ store: any PendingClaimEstimateStore, clock: any Kit.Clocks.Clock) -> PendingClaimEstimateCoordinator {
        return PendingClaimEstimateCoordinator(
            store: store,
            validator: defaultPendingClaimEstimateValidator(),
            clock: clock,
            journal: []
        )
    }
}
