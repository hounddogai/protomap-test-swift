import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves bed board requests through their life cycle and keeps a journal of what it did.
    final class BedBoardRequestService {
        var store: any BedBoardRequestStore
        var validator: BedBoardRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BedBoardRequestEngine

        init(store: any BedBoardRequestStore, validator: BedBoardRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BedBoardRequestEngine) {
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
                throw Kit.Failure("bed board request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BedBoardRequestStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BedBoardRequestStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board request \(code) not found")
            }
            let result = engine.price(item)
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

    static func newBedBoardRequestService(_ store: any BedBoardRequestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BedBoardRequestService {
        return BedBoardRequestService(
            store: store,
            validator: defaultBedBoardRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultBedBoardRequestEngine(flags)
        )
    }
}
