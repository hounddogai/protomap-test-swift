import AcmePlatform
import Foundation

extension Imaging {
    /// Moves default study rollups through their life cycle and keeps a journal of what it did.
    final class DefaultStudyRollupWorkflow {
        var store: any DefaultStudyRollupStore
        var validator: DefaultStudyRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultStudyRollupEngine

        init(store: any DefaultStudyRollupStore, validator: DefaultStudyRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultStudyRollupEngine) {
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
                throw Kit.Failure("default study rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultStudyRollupStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default study rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultStudyRollupStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default study rollup \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newDefaultStudyRollupWorkflow(_ store: any DefaultStudyRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultStudyRollupWorkflow {
        return DefaultStudyRollupWorkflow(
            store: store,
            validator: defaultDefaultStudyRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultStudyRollupEngine(flags)
        )
    }
}
