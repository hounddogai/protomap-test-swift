import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves bed board allocations through their life cycle and keeps a journal of what it did.
    final class BedBoardAllocationCoordinator {
        var store: any BedBoardAllocationStore
        var validator: BedBoardAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BedBoardAllocationEngine

        init(store: any BedBoardAllocationStore, validator: BedBoardAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BedBoardAllocationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BedBoardAllocationStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BedBoardAllocationStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board allocation \(code) not found")
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

    static func newBedBoardAllocationCoordinator(_ store: any BedBoardAllocationStore, clock: any Kit.Clocks.Clock) -> BedBoardAllocationCoordinator {
        return BedBoardAllocationCoordinator(
            store: store,
            validator: defaultBedBoardAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultBedBoardAllocationEngine()
        )
    }
}
