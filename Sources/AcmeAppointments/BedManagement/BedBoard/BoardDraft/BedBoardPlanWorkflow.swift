import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves bed board plans through their life cycle and keeps a journal of what it did.
    final class BedBoardPlanCoordinator {
        var store: any BedBoardPlanStore
        var validator: BedBoardPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BedBoardPlanEngine

        init(store: any BedBoardPlanStore, validator: BedBoardPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BedBoardPlanEngine) {
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
                throw Kit.Failure("bed board plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BedBoardPlanStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BedBoardPlanStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board plan \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newBedBoardPlanCoordinator(_ store: any BedBoardPlanStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BedBoardPlanCoordinator {
        return BedBoardPlanCoordinator(
            store: store,
            validator: defaultBedBoardPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultBedBoardPlanEngine(flags)
        )
    }
}
