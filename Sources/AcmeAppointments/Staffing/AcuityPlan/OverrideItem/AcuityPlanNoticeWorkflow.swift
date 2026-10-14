import AcmePlatform
import Foundation

extension Staffing {
    /// Moves acuity plan notices through their life cycle and keeps a journal of what it did.
    final class AcuityPlanNoticeService {
        var store: any AcuityPlanNoticeStore
        var validator: AcuityPlanNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AcuityPlanNoticeEngine

        init(store: any AcuityPlanNoticeStore, validator: AcuityPlanNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AcuityPlanNoticeEngine) {
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
                throw Kit.Failure("acuity plan notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AcuityPlanNoticeStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AcuityPlanNoticeStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan notice \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newAcuityPlanNoticeService(_ store: any AcuityPlanNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AcuityPlanNoticeService {
        return AcuityPlanNoticeService(
            store: store,
            validator: defaultAcuityPlanNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultAcuityPlanNoticeEngine(flags)
        )
    }
}
