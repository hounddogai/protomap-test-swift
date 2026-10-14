import AcmePlatform
import Foundation

extension Imaging {
    /// Moves regional study rollups through their life cycle and keeps a journal of what it did.
    final class RegionalStudyRollupCoordinator {
        var store: any RegionalStudyRollupStore
        var validator: RegionalStudyRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalStudyRollupEngine

        init(store: any RegionalStudyRollupStore, validator: RegionalStudyRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalStudyRollupEngine) {
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
                throw Kit.Failure("regional study rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalStudyRollupStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional study rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalStudyRollupStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional study rollup \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRegionalStudyRollupCoordinator(_ store: any RegionalStudyRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalStudyRollupCoordinator {
        return RegionalStudyRollupCoordinator(
            store: store,
            validator: defaultRegionalStudyRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalStudyRollupEngine(flags)
        )
    }
}
