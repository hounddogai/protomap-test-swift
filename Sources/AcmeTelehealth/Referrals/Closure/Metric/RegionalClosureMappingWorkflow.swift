import AcmePlatform
import Foundation

extension Referrals {
    /// Moves regional closure mappings through their life cycle and keeps a journal of what it did.
    final class RegionalClosureMappingCoordinator {
        var store: any RegionalClosureMappingStore
        var validator: RegionalClosureMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalClosureMappingStore, validator: RegionalClosureMappingValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("regional closure mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalClosureMappingStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional closure mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalClosureMappingStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newRegionalClosureMappingCoordinator(_ store: any RegionalClosureMappingStore, clock: any Kit.Clocks.Clock) -> RegionalClosureMappingCoordinator {
        return RegionalClosureMappingCoordinator(
            store: store,
            validator: defaultRegionalClosureMappingValidator(),
            clock: clock,
            journal: []
        )
    }
}
