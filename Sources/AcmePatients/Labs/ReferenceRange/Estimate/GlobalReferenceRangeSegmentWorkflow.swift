import AcmePlatform
import Foundation

extension Labs {
    /// Moves global reference range segments through their life cycle and keeps a journal of what it did.
    final class GlobalReferenceRangeSegmentCoordinator {
        var store: any GlobalReferenceRangeSegmentStore
        var validator: GlobalReferenceRangeSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalReferenceRangeSegmentEngine

        init(store: any GlobalReferenceRangeSegmentStore, validator: GlobalReferenceRangeSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalReferenceRangeSegmentEngine) {
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
                throw Kit.Failure("global reference range segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalReferenceRangeSegmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global reference range segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalReferenceRangeSegmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global reference range segment \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newGlobalReferenceRangeSegmentCoordinator(_ store: any GlobalReferenceRangeSegmentStore, clock: any Kit.Clocks.Clock) -> GlobalReferenceRangeSegmentCoordinator {
        return GlobalReferenceRangeSegmentCoordinator(
            store: store,
            validator: defaultGlobalReferenceRangeSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalReferenceRangeSegmentEngine()
        )
    }
}
