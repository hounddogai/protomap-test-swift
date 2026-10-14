import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure estimates through their life cycle and keeps a journal of what it did.
    final class DisclosureEstimateService {
        var store: any DisclosureEstimateStore
        var validator: DisclosureEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DisclosureEstimateEngine

        init(store: any DisclosureEstimateStore, validator: DisclosureEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DisclosureEstimateEngine) {
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
                throw Kit.Failure("disclosure estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosureEstimateStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosureEstimateStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure estimate \(code) not found")
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

    static func newDisclosureEstimateService(_ store: any DisclosureEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DisclosureEstimateService {
        return DisclosureEstimateService(
            store: store,
            validator: defaultDisclosureEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultDisclosureEstimateEngine(flags)
        )
    }
}
