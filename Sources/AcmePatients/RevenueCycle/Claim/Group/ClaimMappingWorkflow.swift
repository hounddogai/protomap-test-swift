import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim mappings through their life cycle and keeps a journal of what it did.
    final class ClaimMappingCoordinator {
        var store: any ClaimMappingStore
        var validator: ClaimMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ClaimMappingStore, validator: ClaimMappingValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("claim mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimMappingStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimMappingStatus.withdrawn)
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

    static func newClaimMappingCoordinator(_ store: any ClaimMappingStore, clock: any Kit.Clocks.Clock) -> ClaimMappingCoordinator {
        return ClaimMappingCoordinator(
            store: store,
            validator: defaultClaimMappingValidator(),
            clock: clock,
            journal: []
        )
    }
}
