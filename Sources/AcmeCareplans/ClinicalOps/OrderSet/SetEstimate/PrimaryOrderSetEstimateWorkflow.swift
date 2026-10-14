import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves primary order set estimates through their life cycle and keeps a journal of what it did.
    final class PrimaryOrderSetEstimateService {
        var store: any PrimaryOrderSetEstimateStore
        var validator: PrimaryOrderSetEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryOrderSetEstimateEngine

        init(store: any PrimaryOrderSetEstimateStore, validator: PrimaryOrderSetEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryOrderSetEstimateEngine) {
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
                throw Kit.Failure("primary order set estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryOrderSetEstimateStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary order set estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryOrderSetEstimateStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary order set estimate \(code) not found")
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

    static func newPrimaryOrderSetEstimateService(_ store: any PrimaryOrderSetEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryOrderSetEstimateService {
        return PrimaryOrderSetEstimateService(
            store: store,
            validator: defaultPrimaryOrderSetEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryOrderSetEstimateEngine(flags)
        )
    }
}
