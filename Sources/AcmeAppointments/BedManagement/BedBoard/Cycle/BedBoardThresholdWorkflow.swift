import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves bed board thresholds through their life cycle and keeps a journal of what it did.
    final class BedBoardThresholdWorkflow {
        var store: any BedBoardThresholdStore
        var validator: BedBoardThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BedBoardThresholdEngine

        init(store: any BedBoardThresholdStore, validator: BedBoardThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BedBoardThresholdEngine) {
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
                throw Kit.Failure("bed board threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BedBoardThresholdStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BedBoardThresholdStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board threshold \(code) not found")
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
                if item.startsAt > cutoff {
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

    static func newBedBoardThresholdWorkflow(_ store: any BedBoardThresholdStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BedBoardThresholdWorkflow {
        return BedBoardThresholdWorkflow(
            store: store,
            validator: defaultBedBoardThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultBedBoardThresholdEngine(flags)
        )
    }
}
