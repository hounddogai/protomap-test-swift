import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist mappings through their life cycle and keeps a journal of what it did.
    final class WorklistMappingWorkflow {
        var store: any WorklistMappingStore
        var validator: WorklistMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WorklistMappingEngine

        init(store: any WorklistMappingStore, validator: WorklistMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WorklistMappingEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistMappingStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistMappingStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist mapping \(code) not found")
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

    static func newWorklistMappingWorkflow(_ store: any WorklistMappingStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WorklistMappingWorkflow {
        return WorklistMappingWorkflow(
            store: store,
            validator: defaultWorklistMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultWorklistMappingEngine(flags)
        )
    }
}
