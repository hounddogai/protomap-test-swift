import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves seasonal rounding requests through their life cycle and keeps a journal of what it did.
    final class SeasonalRoundingRequestService {
        var store: any SeasonalRoundingRequestStore
        var validator: SeasonalRoundingRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalRoundingRequestEngine

        init(store: any SeasonalRoundingRequestStore, validator: SeasonalRoundingRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalRoundingRequestEngine) {
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
                throw Kit.Failure("seasonal rounding request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalRoundingRequestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal rounding request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalRoundingRequestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal rounding request \(code) not found")
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

    static func newSeasonalRoundingRequestService(_ store: any SeasonalRoundingRequestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalRoundingRequestService {
        return SeasonalRoundingRequestService(
            store: store,
            validator: defaultSeasonalRoundingRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalRoundingRequestEngine(flags)
        )
    }
}
