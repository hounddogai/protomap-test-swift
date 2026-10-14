import AcmePlatform
import Foundation

extension Consent {
    /// Moves default language allocations through their life cycle and keeps a journal of what it did.
    final class DefaultLanguageAllocationCoordinator {
        var store: any DefaultLanguageAllocationStore
        var validator: DefaultLanguageAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DefaultLanguageAllocationStore, validator: DefaultLanguageAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("default language allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultLanguageAllocationStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default language allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultLanguageAllocationStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newDefaultLanguageAllocationCoordinator(_ store: any DefaultLanguageAllocationStore, clock: any Kit.Clocks.Clock) -> DefaultLanguageAllocationCoordinator {
        return DefaultLanguageAllocationCoordinator(
            store: store,
            validator: defaultDefaultLanguageAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
