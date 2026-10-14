import AcmePlatform
import Foundation

extension Imaging {
    /// Moves capped study allocations through their life cycle and keeps a journal of what it did.
    final class CappedStudyAllocationDesk {
        var store: any CappedStudyAllocationStore
        var validator: CappedStudyAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedStudyAllocationEngine

        init(store: any CappedStudyAllocationStore, validator: CappedStudyAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedStudyAllocationEngine) {
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
                throw Kit.Failure("capped study allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedStudyAllocationStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped study allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedStudyAllocationStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped study allocation \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newCappedStudyAllocationDesk(_ store: any CappedStudyAllocationStore, clock: any Kit.Clocks.Clock) -> CappedStudyAllocationDesk {
        return CappedStudyAllocationDesk(
            store: store,
            validator: defaultCappedStudyAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedStudyAllocationEngine()
        )
    }
}
