import AcmePlatform
import Foundation

extension Imaging {
    /// Moves tiered study tiers through their life cycle and keeps a journal of what it did.
    final class TieredStudyTierCoordinator {
        var store: any TieredStudyTierStore
        var validator: TieredStudyTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredStudyTierStore, validator: TieredStudyTierValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("tiered study tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredStudyTierStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered study tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredStudyTierStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newTieredStudyTierCoordinator(_ store: any TieredStudyTierStore, clock: any Kit.Clocks.Clock) -> TieredStudyTierCoordinator {
        return TieredStudyTierCoordinator(
            store: store,
            validator: defaultTieredStudyTierValidator(),
            clock: clock,
            journal: []
        )
    }
}
