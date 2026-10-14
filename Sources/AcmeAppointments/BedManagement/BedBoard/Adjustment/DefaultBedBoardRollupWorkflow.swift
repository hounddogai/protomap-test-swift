import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves default bed board rollups through their life cycle and keeps a journal of what it did.
    final class DefaultBedBoardRollupService {
        var store: any DefaultBedBoardRollupStore
        var validator: DefaultBedBoardRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultBedBoardRollupEngine

        init(store: any DefaultBedBoardRollupStore, validator: DefaultBedBoardRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultBedBoardRollupEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default bed board rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultBedBoardRollupStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default bed board rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultBedBoardRollupStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default bed board rollup \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newDefaultBedBoardRollupService(_ store: any DefaultBedBoardRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultBedBoardRollupService {
        return DefaultBedBoardRollupService(
            store: store,
            validator: defaultDefaultBedBoardRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultBedBoardRollupEngine(flags)
        )
    }
}
