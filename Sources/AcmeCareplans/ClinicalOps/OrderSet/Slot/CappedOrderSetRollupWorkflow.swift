import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves capped order set rollups through their life cycle and keeps a journal of what it did.
    final class CappedOrderSetRollupCoordinator {
        var store: any CappedOrderSetRollupStore
        var validator: CappedOrderSetRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedOrderSetRollupStore, validator: CappedOrderSetRollupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped order set rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedOrderSetRollupStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped order set rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedOrderSetRollupStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newCappedOrderSetRollupCoordinator(_ store: any CappedOrderSetRollupStore, clock: any Kit.Clocks.Clock) -> CappedOrderSetRollupCoordinator {
        return CappedOrderSetRollupCoordinator(
            store: store,
            validator: defaultCappedOrderSetRollupValidator(),
            clock: clock,
            journal: []
        )
    }
}
