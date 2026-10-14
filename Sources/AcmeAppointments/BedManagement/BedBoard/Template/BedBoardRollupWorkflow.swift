import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves bed board rollups through their life cycle and keeps a journal of what it did.
    final class BedBoardRollupWorkflow {
        var store: any BedBoardRollupStore
        var validator: BedBoardRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BedBoardRollupEngine

        init(store: any BedBoardRollupStore, validator: BedBoardRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BedBoardRollupEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BedBoardRollupStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BedBoardRollupStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board rollup \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newBedBoardRollupWorkflow(_ store: any BedBoardRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BedBoardRollupWorkflow {
        return BedBoardRollupWorkflow(
            store: store,
            validator: defaultBedBoardRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultBedBoardRollupEngine(flags)
        )
    }
}
